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
            fullKey = "#{target.name}/#{key}"
            if not resource_map.key?(fullKey)
              next
            end
            sourcePath = nil
            if resource_map[fullKey]['target'].start_with?('//') or resource_map[fullKey]['target'].start_with?('@')
              puts 'Relies on Bazel Target'
              sourcePath = Copier.getPathsForTarget(options: options, target: resource_map[fullKey])
            else
              sourcePath = resource_map[fullKey]['target']
            end
            if sourcePath != nil and File.exists?(sourcePath)
              puts "[Resource Bundle Copier] Bundle Found for #{fullKey}"
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
              puts "Missing Source File: #{resource_map[fullKey]['target']}"
            end
          end
        end
      end
    end

    def self.getPathsForTarget(options:, target:)
      command = options['bazelCommand'] ||= 'bazel'
      fullCommand = "#{command} aquery #{target['target']} --output=jsonproto"
      puts "Running Bazel Query to find output location -> #{fullCommand}"
      output = `#{fullCommand}`
      parsed = JSON.parse(output)
      fragments = parsed['pathFragments']

      base = fragments.detect {|fragment| fragment['label'] == target['file']}
      pathSegments = [target['file']]
      parentId = base['parentId']

      while parentId != nil
        frag = fragments.detect {|fragment| fragment['id'] == parentId}
        pathSegments.prepend(frag['label'])
        parentId = frag['parentId']
      end

      while not File.exists?(pathSegments.join('/'))
        pathSegments.prepend('..')
      end
      puts "Found resource for Bazel target: #{pathSegments.join('/')}"
      return pathSegments.join('/')
    end
  end
end