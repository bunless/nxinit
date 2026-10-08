use os::exec;

export type kind = enum {
  TASK,
  SERVICE,
  MILESTONE,
};

export type state = enum {
  CREATED,
  STARTING,
  RUNNING,
  FINISHING,
  FINISHED,
  FAILED,
};

export type unit = struct {
  kind: kind,
  name: str,
  cmd: str,
  process: exec::process,
  state: state,
};

export fn create_unit(unit_kind: kind, unit_name: str, unit_cmd: str) unit = {
	return unit {
    kind = unit_kind,
    name = unit_name,
    cmd = unit_cmd,
    process = -1,
    state = state::CREATED,
	};
};
