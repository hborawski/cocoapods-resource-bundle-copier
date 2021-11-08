require 'json'

module ResourceBundleCopier
  PLUGIN_KEY = "cocoapods-resource-bundle-copier"
  class Copier
    def self.pre_install(installer:)
      options = installer.podfile.plugins[PLUGIN_KEY]
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
            else
              sourcePaths = resource_map[fullKey]['files']
            end

            if not sourcePaths.empty?
              for sourcePath in sourcePaths
                if File.exists?(sourcePath)
                  puts "[Resource Bundle Copier] Resource Found for #{fullKey}"
                  destPath = File.join(rootDir, consumer.resource_bundles[key])
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
                else
                  puts "[Resource Bundle Copier] Missing Source File: #{sourcePath}"
                end
              end
            end
          end
        end
      end
    end

    def self.getPathsForTarget(options:, target:)
      command = options['bazelCommand'] ||= 'bazel'
      fullCommand = "#{command} aquery #{target['target']} --output=jsonproto"
      puts "[Resource Bundle Copier] Running Bazel Query to find output location -> #{fullCommand}"
      output = `#{fullCommand}`
      parsed = JSON.parse(output)

      return target['files'].map {|file| Copier.getPathForTarget(queryJson: parsed, file: file) }
    end

    def self.getPathForTarget(queryJson:, file:)
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