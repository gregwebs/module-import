class ImportError < Exception; end

module Kernel

  # abstraction:: only include the methods given by _meths_
  # implementation:: includes a duplicate of _mod_ with only the specified instance methods included.  By default, all private methods will be included unless the option :import_private is set to false.  If no methods are given,
  def import(mod, *methods_or_options)
    mod_dup = mod.dup

    unless methods_or_options.empty?
      options, meths = methods_or_options.partition {|m| m.is_a?(Hash)}

      # get list of methods to remove module
      ims = mod.instance_methods
      if options.first
        if meths.empty?
          fail ArgumentError,
            "methods arguments required with options flags"
        end
        if options.first[:import_private] == false
          ims += mod.private_instance_methods
        end
      end
      ims.map! {|m| m.to_sym}
      removes = ims - meths

      if removes.size != (ims.size - meths.size)
        raise ImportError,
          "##{(meths - ims).join(' and #')} not found in #{mod}"
      end

      mod_dup.module_eval do
        removes.each { |meth| remove_method meth }
      end
    end

    include mod_dup
  end
end
