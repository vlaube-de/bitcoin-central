class Trade < ActiveRecord::Base
  # TODO : Why is this commented out ?
  # default_scope order("created_at DESC")

  after_create :execute

  belongs_to :purchase_order,
    :class_name => "TradeOrder"

  belongs_to :sale_order,
    :class_name => "TradeOrder"

  belongs_to :seller,
    :class_name => "User"

  belongs_to :buyer,
    :class_name => "User"

  has_many :transfers

  validates :purchase_order,
    :presence => true

  validates :sale_order,
    :presence=> true

  validates :traded_btc,
    :numericality => true,
    :presence => true

  validates :traded_currency,
    :numericality => true,
    :presence => true

  validates :ppc,
    :numericality => true,
    :presence => true

  validates :currency,
    :inclusion => { :in => Transfer::CURRENCIES },
    :presence => true

  scope :last_24h, lambda {
    where("created_at >= ?", DateTime.now.advance(:hours => -24))
  }

  # TODO : Dry up (duplicated in TradeOrder)
  scope :with_currency, lambda { |currency|
    where("currency = ?", currency.to_s.upcase)
  }

  def execute
    transfers << InternalTransfer.create!(
      :currency => currency,
      :amount =>  -traded_currency,
      :user_id => purchase_order.user_id,
      :payee_id => sale_order.user_id,
      :skip_min_amount => true
    )

    transfers << BitcoinTransfer.create!(
      :currency => "BTC",
      :amount => -traded_btc,
      :user_id => sale_order.user_id,
      :payee_id => purchase_order.user_id,
      :skip_min_amount => true
    )

    save!
  end
end
