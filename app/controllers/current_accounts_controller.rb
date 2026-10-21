class CurrentAccountsController < ApplicationController
  PER_PAGE = 30

  before_action :set_current_account, only: %i[ show edit update destroy ]

  def index
    @date = parse_date(params[:date])
    scope = current_accounts
    scope = scope.on_date(@date) if @date

    @balance = scope.balance
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @current_accounts = scope.ordered.limit(PER_PAGE + 1).offset((@page - 1) * PER_PAGE).to_a
    @next_page = @current_accounts.size > PER_PAGE
    @current_accounts = @current_accounts.first(PER_PAGE)
  end

  def show
  end

  def new
    @current_account = current_accounts.new(date_ocurrence: Date.current, type_launche: :debito)
  end

  def edit
  end

  def create
    @current_account = current_accounts.new(current_account_params)

    if @current_account.save
      redirect_to current_accounts_path, notice: "Lançamento cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @current_account.update(current_account_params)
      redirect_to @current_account, notice: "Lançamento atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @current_account.destroy!
    redirect_to current_accounts_path, notice: "Lançamento removido.", status: :see_other
  end

  private
    def current_accounts
      Current.user.current_accounts
    end

    def set_current_account
      @current_account = current_accounts.find(params[:id])
    end

    def current_account_params
      params.expect(current_account: [ :cash_account_id, :cost_id, :type_launche, :date_ocurrence, :price, :historic ])
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
