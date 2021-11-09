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
    describe 'getPathsForTarget' do
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
      it 'gets the paths for a target in a directory higher than itself' do
        ResourceBundleCopier::BazelAQuery.stubs(:runQuery).returns(fakeOutput())
        File.stubs(:exists?).returns(false, true)
        paths = ResourceBundleCopier::Copier.getPathsForTarget(options: {}, target: {
          "target" => "//some/bazel/target/...",
          "files" => ['file.extension']
        })
  
        paths.length.should.equal 1
        paths[0].should.equal '../root/subdir/file.extension'
      end
    end
    describe 'copyFile' do
      it 'create a destination directory for folders or a file' do
        FileUtils.stubs(:cp_r).returns(true)
        FileUtils.expects(:mkdir_p).with('/somefolder').once
        FileUtils.expects(:mkdir_p).with('/somefolder/someotherfolder').once
        ResourceBundleCopier::Copier.copyFile(source: '/files/somefile.txt', dest: '/somefolder')
        ResourceBundleCopier::Copier.copyFile(source: '/files/somefile.txt',dest: '/somefolder/someotherfolder/somefile.txt')
      end
      it 'copies a file into a folder' do
        FileUtils.stubs(:cp_r).returns(true)
        FileUtils.stubs(:mkdir_p).returns(true)
        FileUtils.expects(:cp_r).with('/files/somefile.txt', '/somefolder/', {:remove_destination => true})
        ResourceBundleCopier::Copier.copyFile(source: '/files/somefile.txt', dest: '/somefolder/')
      end
      it 'copies a file into a folder that was a glob' do
        FileUtils.stubs(:cp_r).returns(true)
        FileUtils.stubs(:mkdir_p).returns(true)
        FileUtils.expects(:cp_r).with('/files/somefile.txt', '/somefolder', {:remove_destination => true})
        ResourceBundleCopier::Copier.copyFile(source: '/files/somefile.txt', dest: '/somefolder/**/*.txt')
      end
      it 'copies a file to another file' do
        FileUtils.stubs(:cp_r).returns(true)
        FileUtils.stubs(:mkdir_p).returns(true)
        FileUtils.expects(:cp_r).with('/files/somefile.txt', '/somefolder/somefile.txt', {:remove_destination => true})
        ResourceBundleCopier::Copier.copyFile(source: '/files/somefile.txt', dest: '/somefolder/somefile.txt')
      end
      it 'copies a folder of files into a folder' do
        File.stubs(:directory?).returns(true)
        FileUtils.stubs(:cp_r).returns(true)
        FileUtils.stubs(:mkdir_p).returns(true)
        FileUtils.expects(:cp_r).with('/files/.', '/somefolder/', {:remove_destination => true})
        ResourceBundleCopier::Copier.copyFile(source: '/files/', dest: '/somefolder/')
      end
      it 'copies a file from a folder to a single destination file' do
        File.stubs(:directory?).returns(true, false)
        FileUtils.stubs(:cp_r).returns(true)
        FileUtils.stubs(:mkdir_p).returns(true)
        FileUtils.expects(:cp_r).with('/files/file.txt', '/somefolder/file.txt', {:remove_destination => true})
        ResourceBundleCopier::Copier.copyFile(source: '/files/', dest: '/somefolder/file.txt')
      end
    end
  end
end

