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

  # Credits minus debits: the sign comes from type_launche (-1 or 1).
  def self.balance
    sum("price * type_launche")
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
