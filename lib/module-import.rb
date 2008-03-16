class ImportError < Exception; end

module Kernel

  # abstraction:: only include the methods given by _meths_
  # implementation:: includes a duplicate of _mod_ with only the specified instance methods included.  By default, all private methods will be included unless the option :import_private is set to false.  If no methods are given,
  # option: import_private => false, don't automatically import private methods
  #
  # check for method naming clashes
  # caller can override this behavior with their own block
  # block is yielded private methods, public/protected methods
  # caller can abort include by returning false from the block
  def import(mod, *methods_or_options)
    mod_dup = mod.dup

    privs = mod.private_instance_methods
    ims = mod.instance_methods

    importing = if methods_or_options.empty?
      [privs, ims]
      
    else
      options, meths = methods_or_options.partition {|m| m.is_a?(Hash)}

      # get list of methods to remove module
      if options.first
        if meths.empty?
          fail ArgumentError,
            "methods arguments required with options flags"
        end
        if options.first[:import_private] == false
          ims += privs
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

      [[], meths.map {|m| m.to_sym}]
    end


    # check for method naming clashes
    # caller can override this behavior with their own block
    # block is yielded private methods, public/protected methods
    # caller can abort include by returning false from the block
    if block_given?
      return false if yield *importing == false

    else
      clashes = (private_instance_methods + instance_methods) \
        & importing.flatten
      unless clashes.empty?
        raise ImportError,
          "private methods have conflicts: ##{clashes.join(' and #')}"
      end
    end


    include mod_dup

  end
end
