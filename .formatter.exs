[
  import_deps: [:ecto, :phoenix],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 150,
  locals_without_parens: [assert_that: :*],
  subdirectories: ["priv/*/migrations"]
]
