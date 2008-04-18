class ImportError < Exception; end

module Kernel

  # abstraction:: only include the methods given by _meths_
  # implementation:: includes a duplicate of _mod_ with only the specified instance methods included.  By default, all private methods will be included unless the option :import_private is set to false.  If no methods are given,
  def import(mod, *methods_or_options)
    mod_dup = mod.dup

    unless methods_or_options.empty?
      # get list of methods to remove module
      ims = mod.instance_methods

      meths = []
      modifiers = []
      methods_or_options.each do |m_o|
        case m_o
        when Hash
          bool = m_o.delete(:import_private)
          if bool.nil?
            modifiers.push m_o
          else
            if meths.empty? and methods_or_options.size == 1 and m_o.empty?
              fail ArgumentError,
                "methods arguments required with :import_private flag"
            end
            if bool == false
              ims += mod.private_instance_methods
            end
          end
        else
          meths.push m_o
        end
      end

      ims.map! {|m| m.to_sym}
      removes = ims - meths

      if removes.size != (ims.size - meths.size)
        raise ImportError,
          "##{(meths - ims).join(' and #')} not found in #{mod}"
      end

      mod_dup.module_eval do
        keeps = []
        modifiers.each do |hash|
          hash.each_pair do |meths, modifier|
            meths = meths.is_a?(Array) ? meths : [meths]
            case modifier
            when :as_public
              public *meths
              keeps.concat meths
            when :as_private
              private *meths
              keeps.concat meths

            else # don't keep renamed methods
              meth = meths.pop
              m = modifier.to_s
              m[0..2] == 'as_'
              alias_method :"#{m[3..-1]}", meth
            end
          end
        end

        (removes - keeps).each { |meth| remove_method meth }
      end
    end

    include mod_dup
  end
end
