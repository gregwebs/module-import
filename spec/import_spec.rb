require File.dirname(__FILE__) + '/../lib/import'

module Foo
  def foo; 'foo' end
  def bar; 'bar' end
end

describe "import" do
  it 'should import only the required methods' do
    c = Class.new
    c.send :import, Foo, :bar
    c.new.bar.should == 'bar'
    lambda{c.new.foo}.should raise_error(NoMethodError)
  end

  it 'should raise an error when importing a method that does not exist' do
    lambda{ Class.new.send :import, Foo, :not_defined }.
      should raise_error(ImportError)
  end

  it 'should import all methods if none are given' do
    c = Class.new
    c.send :import, Foo
    c.new.foo.should == 'foo'
    c.new.bar.should == 'bar'

    b = Class.new
    b.send :import, Foo, :foo, :bar
    c.instance_methods.sort.should == b.instance_methods.sort

    a = Class.new
    a.send :include, Foo
    a.instance_methods.sort.should == c.instance_methods.sort
  end

  it 'should not be effected by changes to the module' do
    module Bar
      def foo; 'foo' end
    end

    imp = Class.new
    imp.send :import, Bar
    imp.new.foo.should == 'foo'
    lambda{imp.new.bar}.should raise_error(NoMethodError)

    inc = Class.new
    inc.send :include, Bar
    inc.new.foo.should == 'foo'
    lambda{inc.new.bar}.should raise_error(NoMethodError)

    imp.instance_methods.should == inc.instance_methods

    module Bar
      def bar; 'bar' end
      def foobar; 'foobar' end
    end

    inc.new.foo.should == 'foo'
    inc.new.bar.should == 'bar'

    imp.new.foo.should == 'foo'
    lambda{imp.new.bar}.should raise_error(NoMethodError)

    imp.instance_methods.should_not == inc.instance_methods
  end

  it 'should not effect calls to super' do
    class A
      def foo; 'super' end
    end
    class B < A; end
    B.new.foo.should == 'super'

    class B;
      import Foo, :bar
    end
    B.new.foo.should == 'super'
  end
end
