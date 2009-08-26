require 'erb'

class Context

  def initialize(page)
    @page = page
  end

  def render(*a)
    @page.render(*a)
  end

end


class Page

  def initialize
    @context = Context.new(self)
    @binding = @context.instance_eval{ binding }
  end

  def in1
    %{
      WAY UP HERE
      <%= render('in2') %>
      WAY DOWN HERE
    }
  end

  def in2
    %{
      RIGHT UP HERE
      <%= render('in3') %>
      RIGHT DOWN HERE
    }
  end

  def in3
    "IN THE MIDDLE"
  end

  def render(var)
    input = eval(var)
    template = ERB.new(input)
    template.result(binding)
  end

end

p = Page.new

puts p.render('in1')

