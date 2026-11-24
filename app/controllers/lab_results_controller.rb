class LabResultsController < ApplicationController
  def index
    @result = current_user.lab_results.new
    load_history
  end

  def create
    @result = current_user.lab_results.build(params.expect(lab_result: [ :indicator, :unit, :value, :measured_on ]))
    if @result.save
      redirect_to lab_results_path, notice: "Resultado registrado.", status: :see_other
    else
      load_history
      flash.now[:alert] = "Confira o indicador, a unidade, o valor e a data da coleta."
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_history
    @groups = current_user.lab_results.order(measured_on: :desc, id: :desc).group_by { |r| [ r.indicator.downcase, r.unit ] }
  end
end
