class BuildController < ApplicationController
  
  def show
    find
  end

  def stdout
    send_inline_text(find.stdout)
  end

  def stderr
    send_inline_text(find.stderr)
  end

private

  def find
    @build = Build.find(@params[:id])
  end

  def send_inline_text(text)
    send_data(text, :type => "text/plain".freeze, :disposition => "inline".freeze)
  end

end
