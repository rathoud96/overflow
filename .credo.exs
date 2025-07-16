%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "test/", "apps/"],
        excluded: [~r"_build/", ~r"deps/"]
      },
      checks: [
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Design.TagTODO},
        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.MaxLineLength, max_length: 100},
        {Credo.Check.Refactor.CyclomaticComplexity},
        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect}
      ]
    }
  ]
}
