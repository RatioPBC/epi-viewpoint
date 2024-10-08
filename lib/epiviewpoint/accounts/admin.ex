defmodule EpiViewpoint.Accounts.Admin do
  alias EpiViewpoint.Accounts
  alias EpiViewpoint.AuditingRepo
  alias EpiViewpoint.AuditLog

  @unpersisted_admin_id Application.compile_env(:epiviewpoint, :unpersisted_admin_id)

  def insert_by_admin(%Ecto.Changeset{} = changeset, %AuditLog.Meta{} = audit_meta),
    do: ensure_persisted_or_unpersisted_admin(audit_meta, &AuditingRepo.insert(changeset, &1))

  def insert_by_admin!(%Ecto.Changeset{} = changeset, %AuditLog.Meta{} = audit_meta),
    do: ensure_persisted_or_unpersisted_admin!(audit_meta, &AuditingRepo.insert!(changeset, &1))

  def update_by_admin(%Ecto.Changeset{} = changeset, %AuditLog.Meta{} = audit_meta),
    do: ensure_persisted_admin(audit_meta, &AuditingRepo.update(changeset, &1))

  def ensure_persisted_or_unpersisted_admin(%AuditLog.Meta{} = audit_meta, db_fn) when is_function(db_fn) do
    if persisted_admin?(audit_meta) || unpersisted_admin?(audit_meta),
      do: db_fn.(audit_meta),
      else: {:error, :admin_privileges_required}
  end

  def ensure_persisted_or_unpersisted_admin!(%AuditLog.Meta{} = audit_meta, db_fn) when is_function(db_fn) do
    if persisted_admin?(audit_meta) || unpersisted_admin?(audit_meta),
      do: db_fn.(audit_meta),
      else: raise(EpiViewpoint.AdminRequiredError)
  end

  def ensure_persisted_admin(%AuditLog.Meta{} = audit_meta, db_fn) when is_function(db_fn) do
    if persisted_admin?(audit_meta),
      do: db_fn.(audit_meta),
      else: {:error, :admin_privileges_required}
  end

  def persisted_admin?(%AuditLog.Meta{author_id: @unpersisted_admin_id}),
    do: false

  def persisted_admin?(%AuditLog.Meta{author_id: id}),
    do: Accounts.get_user(id).admin

  def unpersisted_admin?(%AuditLog.Meta{author_id: id}),
    do: id == @unpersisted_admin_id
end
