require File.dirname(__FILE__) + '/../lib/import'

module Foo
  def extra_method; fail end

  def foo; 'foo' end
  def bar; 'bar' end

  def another_extra_method; fail end
end

describe "import" do
  it 'should import only the required methods' do
    klass = Class.new
    klass.send :import, Foo, :bar
    o = klass.new
    o.bar.should == 'bar'
    lambda{o.foo}.should raise_error(NoMethodError)
  end

  it 'should raise an error when importing a method that does not exist' do
    lambda{ Class.new.send :import, Foo, :foo, :not_defined, :bar }.
      should raise_error(ImportError, /#not_defined/)
    lambda{ Class.new.send :import, Foo,
      :not_defined, :foo, :_not_defined_, :bar, :__not_defined__ }.
      should raise_error(ImportError, /#not_defined and #_not_defined_ and #__not_defined__/)
  end

  it 'should import all methods if none are given' do
    c = Class.new
    c.send :import, Foo
    c.new.foo.should == 'foo'
    c.new.bar.should == 'bar'

    b = Class.new
    b.send :import, Foo, *(Foo.private_instance_methods)
    c.instance_methods.sort.should == b.instance_methods.sort

    a = Class.new
    a.send :include, Foo
    a.instance_methods.sort.should == c.instance_methods.sort
  end

  it 'should not be effected by changes to the module' do
    module Bar
      def foo; 'foo' end
    end
    bar_orig_ims = Bar.instance_methods

    imp = Class.new
    imp.send :import, Bar
    inc = Class.new
    inc.send :include, Bar

    [imp, inc].each do |klass|
      k = klass.new
      k.foo.should == 'foo'
      lambda{k.bar}.should raise_error(NoMethodError)
    end

    imp.instance_methods.sort.should == inc.instance_methods.sort
    (bar_orig_ims - imp.instance_methods).should be_empty

    module Bar
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
    (inc.instance_methods - imp.instance_methods).sort.should == (Bar.instance_methods - bar_orig_ims).sort
  end

  it 'should not effect calls to super' do
    class A
      def foo; 'super' end
    end
    class B < A; end
    B.new.foo.should == 'super'

    class B; import Foo, :bar end
    B.new.foo.should == 'super'

    b = B.new
    class << b
      import(Foo, :foo)
    end
    b.foo.should == 'foo'
    B.new.foo.should == 'super'

    class B; import Foo, :foo end
    B.new.foo.should == 'foo'
  end
end
