defmodule Upstream.JobTest do
  use ExUnit.Case

  alias Upstream.Job
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Upstream.B2.{
    LargeFile,
    Upload
  }

  test "create job" do
    job = Job.create("test/fixtures/cute_baby.jpg", "cute_baby_0.jpg")
    {:ok, stat} = File.stat("test/fixtures/cute_baby.jpg")

    assert job.uid.name == "cute_baby_0.jpg"
    assert job.stat == stat
    assert job.content_length == 49_152
  end

  describe "job state change" do
    test "start job" do
      job = Job.create("test/fixtures/cute_baby.jpg", "cute_baby_1.jpg")
      Job.start(job)

      assert Job.State.uploading?(job) == true
    end

    test "job errored" do
      job = Job.create("test/fixtures/cute_baby.jpg", "cute_baby_295.jpg")
      Job.State.start(job)
      Job.State.error(job, "something_failed")

      assert Job.State.get_result(job) == {:error, "something_failed"}
    end

    test "job completed" do
      use_cassette "b2_get_upload_part_url" do
        job = Job.create("test/fixtures/cute_baby.jpg", "cute_baby_234.jpg")
        Job.start(job)

        {:ok, started} = LargeFile.start(job.uid.name)
        {:ok, part_url} = Upload.part_url(started.file_id)

        Job.complete(job, part_url)

        assert Job.completed?(job) == true
        assert Job.get_result(job) == {:ok, Poison.decode!(Poison.encode!(part_url))}
      end
    end

    test "job waiting mechanism" do
      job = Job.create("test/fixtures/cute_baby.jpg", "cute_baby_99887.jpg")

      Job.State.start(job)

      result = Job.get_result(job, 0)

      assert result == {:error, %{error: :no_reply}}
      assert Job.errored?(job) == true
    end
  end
end
