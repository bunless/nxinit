use os::exec;
use unix;
use unix::signal;
use fmt;
use rt;

export fn spawn(cmd: *exec::command, blocked_set: signal::sigset) (int | exec::error) = {
  //try to fork :> and handle errors if they are present
  match (exec::fork()) {
    case let pid: exec::process =>
      return pid;

    case void =>
      signal::setprocmask(signal::how::UNBLOCK, &blocked_set);
      unix::setsid();

      let err = exec::exec(cmd);
      fmt::fatalf("exec failed: {}", exec::strerror(err));

    case let err: exec::error =>
      return err;
  };
};

export fn reap() void = {
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
					case => yield;
				};
		};
	};
};
