[
  import_deps: [:ecto, :phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{heex,ex,exs}"],
  line_length: 150,
  locals_without_parens: [assert_that: :*, flunk: :*],
  subdirectories: ["priv/*/migrations"]
]
