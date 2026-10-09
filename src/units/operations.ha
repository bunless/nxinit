use fmt;
use unix::signal;
use os::exec;
use errors;
use unix;
use rt;

export fn start(unit: *unit, blocked_set: signal::sigset) void = {
	if (unit.state != state::CREATED) {
		return;
	};

	switch (unit.kind) {
	  //task can only be CREATED, STARTING, RUNNING, FINISHED or FAILED
		//service can only be CREATED, STARTING, RUNNING, FINISHING, FINISHED or FAILED
	  case kind::TASK, kind::SERVICE =>
			unit.state = state::STARTING;
			match (spawn(&exec::cmd(unit.cmd)!, blocked_set)) {
			  case let proc: exec::process =>
					unit.state = state::RUNNING;
					unit.process = proc;
				case exec::error =>
				  unit.state = state::FAILED;
			};

	  //milestone can only be CREATED, STARTING, RUNNING, FINISHING, FINISHED or FAILED
	  case kind::MILESTONE =>
			unit.state = state::STARTING;
			//TODO: start milestone dependencies
	};
};

fn spawn(cmd: *exec::command, blocked_set: signal::sigset) (exec::process | exec::error) = {
  //try to fork :> and handle errors if they are present
  match (exec::fork()) {
    case let proc: exec::process =>
      return proc;

    case void =>
      signal::setprocmask(signal::how::UNBLOCK, &blocked_set);
      unix::setsid();

      let err = exec::exec(cmd);
      fmt::fatalf("exec failed: {}", exec::strerror(err));

    case let err: exec::error =>
      return err;
  };
};

export fn finish(unit: *unit) void = {
	if (unit.state != state::RUNNING) {
		return;
	};

	switch (unit.kind) {
	  case kind::TASK =>
			yield;

		case kind::SERVICE =>
		  unit.state = state::FINISHING;

			match (exec::kill(unit.process)) {
			  case =>
					yield;
				case let err: errors::error =>
				  fmt::printfln("finish error: {}", errors::strerror(err))!;
					unit.state = state::FAILED;
				  return;
			};

	  case kind::MILESTONE =>
			unit.state = state::FINISHING;
			//TODO: deactivate milestone dependencies
			unit.state = state::FINISHED;
	};
};

export fn reap(sup: *supervisor) void = {
	let status: int = 0;

	for (true) {
	  //another temp. fix of exec::peekany()
		match (rt::wait4(-1, &status, rt::WNOHANG, null)) {
		  case let err: rt::errno =>
				if (err == rt::ECHILD) {
				  return;
				};
				fmt::printfln("wait4 error: {}", rt::strerror(err))!;
				return;

			case let pid: rt::pid_t =>
			  switch (pid) {
			    case 0 => return;
					case => sync_state(sup, pid, status);
				};
		};
	};
};

fn sync_state(sup: *supervisor, pid: exec::process, status: int) void = {
	for (let i = 0z; i < len(sup.unit_list); i += 1) {
		if (sup.unit_list[i].process: int == pid) {
			if (status == 0) {
			  sup.unit_list[i].state = state::FINISHED;
			} else {
			  sup.unit_list[i].state = state::FAILED;
			};
			return;
		};
	};
};
