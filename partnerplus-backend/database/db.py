from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:1234@localhost/partnerplus_db"
)

engine        = create_engine(DATABASE_URL)
SessionLocal  = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base          = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_tables():
    # Import ALL models so SQLAlchemy knows about them
    from database.models import (
        # Existing
        User, Partner, MOURequest, GeneratedMOU, Event, FollowUp,
        # New
        Call, CallIVRResponse, CallTranscript,
        Notification, Email, Campaign, SponsorSegment,
    )
    Base.metadata.create_all(bind=engine)
    print("✅ All 13 database tables created!")
    print("   Existing : users, partners, mou_requests, generated_mous, events, follow_ups")
    print("   New      : calls, call_ivr_responses, call_transcripts,")
    print("              notifications, emails, campaigns, sponsor_segments")