use fmt;
use unix;
use unix::signal;
use os;
use os::exec;
use fs;
use rt;

use src::power;

//temp fix of exec::wait
fn sigwait(set: *signal::sigset) (signal::sig | rt::errno) = {
	let ret = rt::syscall(
		rt::SYS_rt_sigtimedwait,
		set: uintptr: u64,
		0,
		0,
		8,
	);

	if (ret > -4096: u64) {
		return (-(ret: i64)): rt::errno;
	};

	return ret: signal::sig;
};

export fn main() void = {
  //check if pid1
  if (unix::getpid() != 1) {
    os::exit(1);
  };

  //cd into root
  match (os::chdir("/")) {
    case void => yield;
    case let fs_err: fs::error => fmt::fatalf("Error: {}", fs::strerror(fs_err));
  };

  //set sigset and mask it
  let set: signal::sigset = signal::newsigset(
    signal::sig::CHLD,
    signal::sig::USR1,
    signal::sig::USR2,
  );
  signal::setprocmask(signal::how::BLOCK, &set);

  //spawn commands
  let cmd = exec::cmd("/bin/sh")!;
  spawn(&cmd, set);

  //main loop
  for (true) {
    //error handling of the permanent fix UHH
    match (sigwait(&set)) {
      case let sig: signal::sig =>
        switch (sig) {
          case signal::sig::CHLD => reap();
          case signal::sig::USR1 => power::reboot();
          case signal::sig::USR2 => power::poweroff();
          case => yield;
        };

      case let err: rt::errno =>
        fmt::printfln("sigwait error: {}", rt::strerror(err))!;
        return;
    };
  };
};

fn spawn(cmd: *exec::command, blocked_set: signal::sigset) void = {
  //try to fork :> and handle errors if they are present
  match (exec::fork()) {
    case exec::process => yield;

    case void =>
      signal::setprocmask(signal::how::UNBLOCK, &blocked_set);
      unix::setsid();
      let err = exec::exec(cmd);
      fmt::fatalf("exec failed: {}", exec::strerror(err));

    case exec::error =>
      fmt::println("cant spawn a process")!;
  };
};

fn reap() void = {
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
