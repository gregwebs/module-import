require File.dirname(__FILE__) + '/../lib/module-import'
# TODO
# test and document safeguards against method name clashes

def module_with_new
  Module.new do
    def self.new
      (Class.new.send :include, self).new
    end
  end
end

def class_with_super(superclass)
  if superclass.is_a? Class
    Class.new(superclass)
  else
    module_with_new().module_eval do
      include superclass
    end
  end
end

def class_and_module(times=nil)
  if not times or times == 1
    [Class.new,  module_with_new()]
  else
    [(0...times).map{|i| Class.new}, (0...times).map{|i| module_with_new()}]
  end
end

module ModuleDependencies
  def self.included(mod)
    mod.module_eval do
      @@instance_method_dependencies = Hash.new
    end

    def mod.import_dependencies set=nil
      if set
        @@instance_method_dependencies = set
      else
        @@instance_method_dependencies
      end
    end
  end
end


# testing uses this module
module Foo
  def extra_method; fail end

  def foo; foo_dependency() end
  def bar; bar_dependency end

protected
  def protected_method
  end

private
  def foo_dependency; 'foo' end
  def bar_dependency; 'bar' end
  def private_extra_method; fail end

public
  def another_extra_method; fail end
end

describe "import" do
  it 'should import only the required methods' do
    class_and_module.each do |k|
      k.send :import, Foo, :bar
      o = k.new
      o.bar.should == 'bar'
      lambda{o.foo}.should raise_error(NoMethodError)
    end
  end

  it 'should raise an error when importing a method that does not exist' do
    class_and_module.each {|k| lambda{ k.send :import, Foo, :foo, :not_defined, :bar }.
      should raise_error(ImportError, /#not_defined/) }

    class_and_module.each {|k| lambda{ k.send :import, Foo,
      :not_defined, :foo, :_not_defined_, :bar, :__not_defined__ }.
      should raise_error(ImportError, /#not_defined and #_not_defined_ and #__not_defined__/) }
  end

  it 'should import all methods if none are given' do
    class_and_module.each do |c|
      c.send :import, Foo
      c.new.foo.should == 'foo'
      c.new.bar.should == 'bar'

      a = c.class.new
      a.send :include, Foo
      a.instance_methods.sort.should == c.instance_methods.sort
    end
  end

  it 'should not be effected by changes to the module' do
    class_and_module(2).each do |imp,inc|
      bar = Module.new do
        def foo; 'foo' end
      end
      bar_orig_ims = bar.instance_methods

      imp.send :import, bar
      inc.send :include, bar

      imp.instance_methods.sort.should == inc.instance_methods.sort
      (bar_orig_ims - imp.instance_methods).should be_empty

      [imp, inc].each do |klass|
        k = klass.new
        k.foo.should == 'foo'
        lambda{k.bar}.should raise_error(NoMethodError)
      end

      bar.module_eval do
        def extra_method; fail end

        def bar; 'bar' end
        undef_method :foo

        def another_extra_method; fail end
      end

      lambda{inc.new.foo}.should raise_error(NoMethodError)
      inc.new.bar.should == 'bar'

      imp.new.foo.should == 'foo'
      lambda{imp.new.bar}.should raise_error(NoMethodError)

      (imp.instance_methods - inc.instance_methods).should == ['foo']
      (inc.instance_methods - imp.instance_methods).sort.should == (bar.instance_methods - bar_orig_ims).sort
    end
  end

  it 'should not effect calls to super' do
    class_and_module.each do |a|
      a.class_eval do
        def foo; 'super' end
      end
      b = class_with_super(a)
      b.new.foo.should == 'super'

      b.class_eval { import Foo, :bar }
      b.new.foo.should == 'super'

      bo = b.new
      class << bo
        import(Foo, :foo, :import_private => false)
      end
      bo.foo.should == 'foo'
      b.new.foo.should == 'super'

      b.class_eval { import Foo, :foo }
      b.new.foo.should == 'foo'
    end
  end

  it "should remove private methods when :import_private is false" do
    class_and_module.each do |a|
      b = Class.new do
        import Foo, :foo, :import_private => false
      end
      lambda{b.new.foo}.should raise_error(NoMethodError, /foo_dependency/)

      c = Class.new do
        import Foo, :foo, :foo_dependency, :import_private => false
      end
      lambda{c.new.foo}.should_not raise_error
    end
  end

  it "should fail when no methods given with :import_private flag" do
    class_and_module.each do |a|
      [true,false].each do |tf|
        lambda{ Class.new do
          import Foo, :import_private => tf
        end }.should raise_error(ArgumentError)
      end
    end
  end
end
