# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def action_button(color,title,params={},options={})
    options[:class] = "bt_#{color.to_s}"
    title = %W{<span class="bt_#{color}_lft"></span><strong>#{title}</strong><span class="bt_#{color}_r"></span>}
    link_to title, params, options
  end
  
  def sidebar_button(color,title,params={},options={})
    options[:class] = "menuitem" 
    if color != :blue
      options[:class] += "_#{color.to_s}"
    end
    link_to title, params, options
  end
  
  def dl_submit(title,*args)
    content_tag(:dl,submit_tag(title,*args)) 
  end
  
  def row_to_td(*args)
    row = args.collect { |v| "<td>#{v}</td>" }
    "<tr>#{row.join("\n")}</tr>"
  end

end
