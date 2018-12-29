defmodule Clust do
  use Application

  alias Clust.Ring

  def start(_type, _args) do
    children = [
      Ring
    ]
    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    Supervisor.start_link(children, options)
  end

  def locate(name, module, state) do
    case get(name) do
      nil ->
        spec = module.child_spec([state])
        {:ok, pid} = add(name, spec)
        pid
      pid -> pid
    end
  end

  def get(name) do
    supervisor(name)
    |> Supervisor.which_children
    |> Enum.find_value(fn
      {^name, pid, _type, _modules} -> pid
      {_name, _pid, _type, _modules} -> nil
    end)
  end

  def add(name, spec) do
    dest = supervisor(name)
    spec = Map.put(spec, :id, name)
    Supervisor.start_child(dest, spec)
  end

  def remove(name) do
    delete(supervisor(name), name)
  end

  def handoff(node) do
    __MODULE__
    |> Supervisor.which_children
    |> Enum.filter(fn
      {Ring, _pid, _type, _modules} ->
        false
      {name, _pid, _type, _modules} ->
        Ring.find(name) == node
    end)
    |> Enum.each(&migrate/1)
  end

  defp supervisor(name) do
    {__MODULE__, Ring.find(name)}
  end

  defp delete(dest, name) do
    Supervisor.terminate_child(dest, name)
    Supervisor.delete_child(dest, name)
  end

  defp migrate({name, pid, _type, [module]}) do
    state = :sys.get_state(pid)
    spec = module.child_spec([state])
    delete(__MODULE__, name)

    case add(name, spec) do
      {:error, {:already_started, pid}} ->
        send(pid, {:handoff, state})
      other ->
        other
    end
  end
end
