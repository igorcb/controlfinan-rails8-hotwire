class CurrentAccount < ApplicationRecord
  CASH_ACCOUNTS = {
    0 => "Conta Dinheiro",
    1 => "Itaú",
    2 => "Santander",
    3 => "CEF Poupança",
    4 => "PagSeguro",
    5 => "Uber",
    6 => "Platinum Itaú",
    7 => "Banco do Brasil",
    8 => "99Pop"
  }.freeze

  COSTS = {
    0 => "Combustível",
    1 => "Central",
    2 => "Aluguel Carro",
    3 => "Almoço",
    4 => "Lanche",
    5 => "Diversos",
    6 => "Corridas",
    7 => "Telefone",
    8 => "Lavagem",
    9 => "Transferência",
    10 => "Depósitos",
    11 => "Estacionamento",
    12 => "Impostos",
    13 => "Multas",
    14 => "Manutenção",
    15 => "Viagens Uber"
  }.freeze

  belongs_to :user

  enum :type_launche, { debito: -1, credito: 1 }, validate: true

  validates :cash_account_id, inclusion: { in: CASH_ACCOUNTS.keys }
  validates :cost_id, inclusion: { in: COSTS.keys }
  validates :date_ocurrence, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  scope :ordered, -> { order(date_ocurrence: :desc, id: :desc) }
  scope :on_date, ->(date) { where(date_ocurrence: date) }
  scope :in_month, ->(date) { where(date_ocurrence: date.all_month) }
  scope :rides, -> { where(cost_id: RIDES) }

  RIDES = 6
  # Ride expenses discounted from rides in the monthly balance (legacy dashboard rule).
  RIDE_EXPENSES = { 0 => "Combustível", 8 => "Lavagem", 7 => "Telefone" }.freeze

  # Credits minus debits: the sign comes from type_launche (-1 or 1).
  def self.balance
    sum("price * type_launche")
  end

  # { date => balance }, most recent first
  def self.balance_by_day
    group(:date_ocurrence).order(date_ocurrence: :desc).sum("price * type_launche")
  end

  # { cost_id => sum of price }, only for the given categories
  def self.total_by_cost(cost_ids)
    where(cost_id: cost_ids).group(:cost_id).sum(:price)
  end

  def name_account
    CASH_ACCOUNTS.fetch(cash_account_id, "Não definido")
  end

  def name_cost
    COSTS.fetch(cost_id, "Não definido")
  end

  def type_launche_name
    credito? ? "Crédito" : "Débito"
  end

  def signed_price
    credito? ? price : -price
  end
end
