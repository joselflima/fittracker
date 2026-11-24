class WaterEntriesController < ApplicationController
  def create
    entry = current_user.water_entries.build(milliliters: params[:milliliters])
    if entry.save
      redirect_to root_path, notice: "Água registrada.", status: :see_other
    else
      redirect_to root_path, alert: "Informe um volume positivo em ml.", status: :see_other
    end
  end
end
