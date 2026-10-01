class ContactsController < ApplicationController
  before_action :set_contact, except: :index

  def index
    @contacts = Contact.order(updated_at: :desc)
    if params[:q].present?
      q = "%#{Contact.sanitize_sql_like(params[:q])}%"
      @contacts = @contacts.where("name ILIKE :q OR profile_name ILIKE :q OR phone LIKE :q", q: q)
    end
  end

  def show
    @conversations = @contact.conversations.recent
    @tickets = @contact.tickets.order(created_at: :desc)
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to @contact, notice: "Contact updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.expect(contact: %i[ name notes ])
    end
end
