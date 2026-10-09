use unix::signal;
use unix;
use os::exec;

export type supervisor = struct {
	unit_list: []unit,
};

export fn create_supervisor() supervisor = {
	return supervisor {
		unit_list = [],
	};
};

export fn append_unit(sup: *supervisor, unit: unit) void = {
	match (append(sup.unit_list, unit)) {
	  case void =>
			yield;
		case nomem =>
		  abort();
	};
};

export fn start_all(sup: *supervisor, blocked_set: signal::sigset) void = {
	for (let i = 0z; i < len(sup.unit_list); i += 1) {
		start(&sup.unit_list[i], blocked_set);
	};
};

export fn finish_all(sup: *supervisor) void = {
	for (let i = 0z; i < len(sup.unit_list); i += 1) {
		finish(&sup.unit_list[i]);
	};
};
