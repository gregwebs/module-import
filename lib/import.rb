class ImportError < Exception; end

module Kernel

  # abstraction:: only include the methods given by _meths_
  # implementation:: includes a duplicate of _mod_ with all uneeded instance methods removed
  def import(mod, *meths)
    include_module_copy = lambda do |block|
      mod_dup = mod.dup
      mod_dup.module_eval(&block) if block
      include mod_dup
    end

    if meths.size == 0
      include_module_copy.call(nil)

    else
      # get list of methods to remove module
      ims = mod.instance_methods.map {|m| m.to_sym}
      removes = ims - meths
      if removes.size != (ims.size - meths.size)
        raise ImportError, "##{(meths - ims).join(' and #')} not found in #{mod}"
      end

      include_module_copy.call( lambda do
        removes.each { |meth| remove_method meth }
      end )
    end
  end
end
