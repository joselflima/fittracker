class SleepEntriesController < ApplicationController
  def create
    hours, minutes = params.values_at(:hours, :minutes).map { |v| Integer(v, exception: false) }
    if hours&.between?(0, 24) && minutes&.between?(0, 59) && hours * 60 + minutes <= 1440
      current_user.with_lock do
        current_user.sleep_entries.find_or_initialize_by(day: Date.current).update!(minutes: hours * 60 + minutes)
      end
      redirect_to root_path, notice: "Sono registrado.", status: :see_other
    else
      redirect_to root_path, alert: "Confira as horas e os minutos de sono.", status: :see_other
    end
  end
end
