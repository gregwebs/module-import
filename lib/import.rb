class ImportError < Exception; end

module Kernel
  # include an anonymous module with all uneeded instance methods removed
  def import(mod, *meths)
    include_anonymous_module = lambda do |block|
      include( Module.new do
        this = self

        mod.module_eval do
          (@@undef_methods_for ||= []).push(this)

          class << self
            unless self.respond_to? :__import_method_added__
              alias_method :__import_method_added__, :method_added
            end

            def method_added(traced)
              @@undef_methods_for.each do |mod|
                mod.send :undef_method, traced #if mod.instance_methods.include? traced
              end
              self.send :__import_method_added__, traced
            end
          end

        end

        include mod
        instance_eval &block if block
      end )
    end

    if meths.size == 0
      include_anonymous_module.call(nil)

    else
      include_anonymous_module.call( lambda do

        # get list of methods to remove from anonymous module
        ims = mod.instance_methods.map{|m| m.to_sym}
        meths.map do |meth|
          ims.index(meth) || (raise ImportError, "##{meth} not found in #{mod}")
        end.sort.reverse_each do |i|
          ims.delete_at(i)
        end

        ims.each do |meth|
          undef_method meth # breaks inheritance for the method
        end
      end
      )
    end
  end
end
