class ImportError < Exception; end

module Kernel

  # abstraction:: only include the methods given by _meths_
  # implementation:: includes a duplicate of _mod_ with all uneeded instance methods removed
  def import(mod, *meths)
    mod_dup = mod.dup

    unless meths.empty?

      # get list of methods to remove module
      ims = mod.instance_methods.map {|m| m.to_sym}
      removes = ims - meths

      if removes.size != (ims.size - meths.size)
        raise ImportError, "##{(meths - ims).join(' and #')} not found in #{mod}"
      end

      mod_dup.module_eval do
        removes.each { |meth| remove_method meth }
      end
    end

    include mod_dup
  end
end
