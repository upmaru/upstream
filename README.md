# Upstream

[![Build status](https://badge.buildkite.com/ee2ae25e635383a904e143c59088604087d7d405213b3df2cb.svg)](https://buildkite.com/upmaru/upstream)

Module for handling file upload can be mounted in any `Phoenix` app via the phoenix router.

It supports simple single thread uploading or multi-threaded uploading provided the client supports it. More details coming soon, as we add tests and finalize the module.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `upstream` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:upstream, "~> 1.5.9"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/upstream](https://hexdocs.pm/upstream).
