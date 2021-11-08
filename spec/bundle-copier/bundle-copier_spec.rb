require File.expand_path('../../spec_helper', __FILE__)

def fakeOutput
  output = <<~HEREDOC
  {
    "pathFragments": [
      {
        "id": 1,
        "label": "root"
      },
      {
        "id": 2,
        "label": "subdir",
        "parentId": 1
      },
      {
        "id": 3,
        "label": "file.extension",
        "parentId": 2
      }
    ]
  }
              HEREDOC
  return JSON.parse(output)
end

module ResourceBundleCopier
  describe ResourceBundleCopier::Copier do
    it 'gets the paths for a target' do
      ResourceBundleCopier::BazelAQuery.stubs(:runQuery).returns(fakeOutput())
      File.stubs(:exists?).returns(true)
      paths = ResourceBundleCopier::Copier.getPathsForTarget(options: {}, target: {
        "target" => "//some/bazel/target/...",
        "files" => ['file.extension']
      })

      paths.length.should.equal 1
      paths[0].should.equal 'root/subdir/file.extension'
    end
  end
end

