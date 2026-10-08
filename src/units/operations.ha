use fmt;
use unix::signal;
use os::exec;
use errors;

use src::processes;

export fn start(unit: *unit, blocked_set: signal::sigset) void = {
	switch (unit.kind) {
	  //task can only be CREATED, STARTING, RUNNING, FINISHED or FAILED
	  case kind::TASK =>
			unit.state = state::STARTING;

			match (processes::spawn(&exec::cmd(unit.cmd)!, blocked_set)) {
			  case let proc: exec::process =>
					unit.state = state::RUNNING;
					unit.process = proc;
				case exec::error =>
				  unit.state = state::FAILED;
			};

	  //service can only be CREATED, STARTING, RUNNING, FINISHING, FINISHED or FAILED
	  case kind::SERVICE =>
			unit.state = state::STARTING;
			match (processes::spawn(&exec::cmd(unit.cmd)!, blocked_set)) {
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

export fn finish(unit: *unit) void = {
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
		  match (exec::wait(&unit.process)) {
				case let st: exec::status => unit.state = state::FINISHED;
				case let err: errors::error =>
				  unit.state = state::FAILED;
				  return;
			};

	  case kind::MILESTONE =>
			unit.state = state::FINISHING;
			//TODO: deactivate milestone dependencies
			unit.state = state::FINISHED;
	};
};
