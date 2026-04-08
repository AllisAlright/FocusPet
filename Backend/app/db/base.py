from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    # All database tables inherit from this shared SQLAlchemy base class.
    pass
