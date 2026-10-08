use fmt;
use unix::signal;
use os::exec;

use src::processes;

export fn start(unit: *unit, blocked_set: signal::sigset) void = {
	switch (unit.kind) {
	  //task can only be CREATED, STARTING, FINISHED or FAILED
	  case kind::TASK =>
			unit.state = state::STARTING;
			match (processes::spawn(&exec::cmd(unit.cmd)!, blocked_set)) {
			  case => unit.state = state::FINISHED;
				case exec::error => unit.state = state::FAILED;
			};

	  //service can only be CREATED, STARTING, RUNNING, FINISHING, FINISHED or FAILED
	  case kind::SERVICE =>
			unit.state = state::STARTING;
			match (processes::spawn(&exec::cmd(unit.cmd)!, blocked_set)) {
			  case let pid: int =>
					unit.state = state::RUNNING;
					unit.pid = pid;
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
			// no need to finish tasks
			yield;
	  case kind::SERVICE =>
			unit.state = state::FINISHING;
			//TODO: terminate unit.pid
			//TODO: wait for process
			unit.state = state::FINISHED;
	  case kind::MILESTONE =>
			unit.state = state::FINISHING;
			//TODO: deactivate milestone dependencies
			unit.state = state::FINISHED;
	};
};
