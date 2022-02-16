require 'json'

module ResourceBundleCopier
  class BazelAQuery
    def self.runQuery(target:, command:)
      return JSON.parse(`#{command} aquery #{target} --output=jsonproto`)
    end
  end

  PLUGIN_KEY = "cocoapods-resource-bundle-copier"
  class Copier
    def self.pre_install(installer:)
      options = installer.podfile.plugins[PLUGIN_KEY] ||= {}
      resource_map = options['resource_map'] ||= {}
      puts "[Resource Bundle Copier] Running"
      installer.development_pod_targets.each do |target|
        rootDir = installer.sandbox.pod_dir(target.name)
        target.spec_consumers.each do |consumer|
          consumer.resource_bundles.keys.each do |key|
            # Pod Name / Subspec
            fullKey = "#{target.name}/#{key}"
            if not resource_map.key?(fullKey)
              next
            end

            sourcePaths = []
            if resource_map[fullKey]['target'] != nil
              puts "[Resource Bundle Copier] #{fullKey} Relies on Bazel Target: #{resource_map[fullKey]['target']}"
              sourcePaths = Copier.getPathsForTarget(options: options, target: resource_map[fullKey])
            elsif resource_map[fullKey]['targets'] != nil
              sourcePaths = resource_map[fullKey]['targets'].flat_map { |target|
                Copier.getPathsForTarget(options: options, target: target)
              }
            else
              sourcePaths = resource_map[fullKey]['files']
            end

            if not sourcePaths.empty?
              for sourcePath in sourcePaths
                if File.exists?(sourcePath)
                  puts "[Resource Bundle Copier] Resource Found for #{fullKey}"
                  destPath = File.join(rootDir, consumer.resource_bundles[key])
                  self.copyFile(source: sourcePath, dest: destPath)
                else
                  puts "[Resource Bundle Copier] Missing Source File: #{sourcePath}"
                end
              end
            end
          end
        end
      end
    end

    def self.copyFile(source:, dest:)
      destPath = dest
      sourcePath = source
      while File.basename(destPath).include?('*')
        destPath = File.dirname(destPath)
      end
      if File.extname(destPath) == ""
        FileUtils.mkdir_p(destPath)
      else
        FileUtils.mkdir_p(File.dirname(destPath))
      end
      if File.directory?(sourcePath)
        if File.directory?(destPath)
          sourcePath = File.join(sourcePath, '.')
        else
          sourcePath = File.join(sourcePath, File.basename(destPath))
        end
      end
      puts "[Resource Bundle Copier] Copying #{sourcePath} to #{destPath}"
      FileUtils.cp_r(sourcePath, destPath, remove_destination: true)
    end

    def self.getPathsForTarget(options:, target:)
      command = options['bazelCommand'] ||= 'bazel'

      queryJson = BazelAQuery.runQuery(target: target['target'], command: command)

      return target['files'].map {|file| Copier.getPathForTarget(queryJson: queryJson, file: file) }
    end

    def self.getPathForTarget(queryJson:, file:)
      puts 'getting path'
      fragments = queryJson['pathFragments']

      base = fragments.detect {|fragment| fragment['label'] == file}
      pathSegments = [file]
      parentId = base['parentId']

      while parentId != nil
        frag = fragments.detect {|fragment| fragment['id'] == parentId}
        pathSegments.prepend(frag['label'])
        parentId = frag['parentId']
      end

      while not File.exists?(pathSegments.join('/'))
        pathSegments.prepend('..')
      end
      puts "[Resource Bundle Copier] Found resource for Bazel target: #{pathSegments.join('/')}"
      return pathSegments.join('/')
    end
  end
end