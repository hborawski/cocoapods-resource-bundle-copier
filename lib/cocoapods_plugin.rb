require 'cocoapods-resource-bundle-copier/bundle-copier'
require 'cocoapods'

module Pod
  class Installer
    method_name = :run_podfile_pre_install_hook
    unless method_defined?(method_name) || private_method_defined?(method_name)
      raise Informative, <<~MSG
        cocoapods-resource-bundle-copier is incompatible with this version of CocoaPods.
        It requires a version with #{self}##{method_name} defined.
      MSG
    end

    unbound_method = instance_method(method_name)
    remove_method(method_name)
    define_method(method_name) do
      ResourceBundleCopier::Copier.pre_install(installer: self)
      unbound_method.bind(self).call
    end
  end
end
