defmodule Theoria.ArtifactReplayTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.ArtifactReplay

  test "accessors expose source counts" do
    replay = %ArtifactReplay{generated_checked: 2, indexed_checked: 3, skipped: [], failures: []}

    assert ArtifactReplay.checked(replay) == 5
    assert ArtifactReplay.generated_checked(replay) == 2
    assert ArtifactReplay.indexed_checked(replay) == 3
    assert ArtifactReplay.sources(replay) == %{generated: 2, indexed: 3}
    assert ArtifactReplay.skipped_count(replay) == 0
  end
end
