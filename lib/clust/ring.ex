defmodule Clust.Ring do
  use GenServer

  alias ExHashRing.HashRing

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    :net_kernel.monitor_nodes(true)
    initialize()
    {:ok, state}
  end

  def find(key) do
    HashRing.find_node(fetch(), key)
  end

  def handle_info({:nodeup, node}, state) do
    update(:add_node, node)
    Clust.handoff(node)
    {:noreply, state}
  end
  def handle_info({:nodedown, node}, state) do
    update(:remove_node, node)
    {:noreply, state}
  end

  defp initialize do
    nodes = Node.list() ++ [node()]
    ring = HashRing.new(nodes, 128)
    FastGlobal.put(__MODULE__, ring)
  end

  defp update(method, node) do
    params = [fetch(), node]
    {:ok, ring} = apply(HashRing, method, params)
    FastGlobal.put(__MODULE__, ring)
  end

  defp fetch do
    FastGlobal.get(__MODULE__)
  end
end
