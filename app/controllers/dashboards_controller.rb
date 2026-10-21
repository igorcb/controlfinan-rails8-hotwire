class DashboardsController < ApplicationController
  def show
    @month = parse_month(params[:month])
    month_accounts = Current.user.current_accounts.in_month(@month)

    @balance_by_day = month_accounts.balance_by_day
    @month_balance = @balance_by_day.values.sum

    @ride_expenses = month_accounts.total_by_cost(CurrentAccount::RIDE_EXPENSES.keys)
    @rides_balance = month_accounts.rides.balance
    @rides_net = @rides_balance - @ride_expenses.values.sum
  end

  private
    def parse_month(value)
      Date.strptime(value, "%Y-%m")
    rescue ArgumentError, TypeError
      Date.current.beginning_of_month
    end
end
