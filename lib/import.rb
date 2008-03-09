class ImportError < Exception; end

module Kernel

  # include a duplicate of the module with all uneeded instance methods removed
  def import(mod, *meths)
    include_module_copy = lambda do |block|
      mod_dup = mod.dup
      mod_dup.module_eval &block if block
      include mod_dup
    end

    if meths.size == 0
      include_module_copy.call(nil)

    else
      # get list of methods to remove module
      ims = mod.instance_methods.map {|m| m.to_sym}
      if (ims & meths).size != meths.size
        raise ImportError, "##{(meths - ims).join(' and #')} not found in #{mod}"
      end
      ims = ims - meths

      include_module_copy.call( lambda do
        ims.each { |meth| remove_method meth }
      end )
    end
  end
end
