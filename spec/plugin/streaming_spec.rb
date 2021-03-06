require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "streaming plugin" do 
  it "adds stream method for streaming responses" do
    app(:streaming) do |r|
      stream do |out|
        %w'a b c'.each{|v| out << v}
      end
    end

    s, h, b = req
    s.should == 200
    h.should == {'Content-Type'=>'text/html'}
    b.to_a.should == %w'a b c'
  end

  it "should handle errors when streaming, and run callbacks" do
    a = []
    app(:streaming) do |r|
      stream(:callback=>proc{a << 'e'}) do |out|
        %w'a b'.each{|v| out << v}
        raise Roda::RodaError, 'foo'
        out << 'c'
      end
    end

    s, h, b = req
    s.should == 200
    h.should == {'Content-Type'=>'text/html'}
    b.callback{a << 'd'}
    proc{b.each{|v| a << v}}.should raise_error(Roda::RodaError)
    a.should == %w'a b e d'
  end

  it "should handle :loop option to loop" do
    a = []
    app(:streaming) do |r|
      b = %w'a b c'
      stream(:loop=>true, :callback=>proc{a << 'e'}) do |out|
        out << b.shift
        raise Roda::RodaError, 'foo' if b.length == 1
      end
    end

    s, h, b = req
    s.should == 200
    h.should == {'Content-Type'=>'text/html'}
    b.callback{a << 'd'}
    proc{b.each{|v| a << v}}.should raise_error(Roda::RodaError)
    a.should == %w'a b e d'
  end
end
