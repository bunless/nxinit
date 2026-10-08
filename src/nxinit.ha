use fmt;
use unix;
use unix::signal;
use os;
use os::exec;
use fs;
use rt;

use src::power;
use src::processes;
use src::units;

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

  //decrale first task and service
  let test_service = units::create_unit(units::kind::SERVICE, "sh", "/bin/sh");
  units::start(&test_service, set);

  let test_task = units::create_unit(units::kind::TASK, "ls", "ls");
  units::start(&test_task, set);

  fmt::printfln("pid: {}", test_service.pid)!;

  //main loopidk
  for (true) {
    //error handling of the permanent fix UHH
    match (sigwait(&set)) {
      case let sig: signal::sig =>
        switch (sig) {
          case signal::sig::CHLD => processes::reap();
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
