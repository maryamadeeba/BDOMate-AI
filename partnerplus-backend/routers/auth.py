"""
BDOMate.AI — Authentication Router
"""

import os
import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from pydantic import BaseModel, EmailStr, field_validator
from sqlalchemy.orm import Session
from jose import jwt
from passlib.context import CryptContext

from database.db import get_db
from database.models import User, PasswordResetToken

# Flutter web base URL — change port to match your Flutter dev server
APP_BASE_URL = os.getenv("APP_BASE_URL", "http://localhost:8080")

router = APIRouter()

# ── Crypto setup ──────────────────────────────────────────────
_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)

SECRET_KEY = os.getenv("SECRET_KEY", "bdoMate-change-this-in-production")
ALGORITHM  = os.getenv("ALGORITHM", "HS256")
TOKEN_MINS = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))


def _hash(password: str) -> str:
    return _pwd.hash(password)


def _verify(plain: str, hashed: str) -> bool:
    return _pwd.verify(plain, hashed)


def _make_token(data: dict) -> str:
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(minutes=TOKEN_MINS)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ── Schemas ───────────────────────────────────────────────────

class SignupRequest(BaseModel):
    full_name:   str
    email:       EmailStr
    password:    str
    designation: str = "BDO"
    role:        str = "bdo"

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

    @field_validator("full_name")
    @classmethod
    def name_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Full name cannot be blank")
        return v.strip()


class LoginRequest(BaseModel):
    email:    EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"
    user:         dict


class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token:        str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


# ── Endpoints ─────────────────────────────────────────────────

@router.post("/signup", response_model=TokenResponse, status_code=201)
def signup(req: SignupRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        full_name     = req.full_name,
        email         = req.email,
        password_hash = _hash(req.password),
        designation   = req.designation,
        role          = req.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = _make_token({
        "sub":       str(user.id),
        "email":     user.email,
        "full_name": user.full_name,
        "role":      user.role,
    })
    return TokenResponse(
        access_token = token,
        user = {
            "id":          user.id,
            "full_name":   user.full_name,
            "email":       user.email,
            "designation": user.designation,
            "role":        user.role,
        }
    )


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    INVALID = HTTPException(
        status_code = status.HTTP_401_UNAUTHORIZED,
        detail      = "Invalid credentials",
        headers     = {"WWW-Authenticate": "Bearer"},
    )

    user: User | None = db.query(User).filter(User.email == req.email).first()
    if not user:
        raise INVALID

    if not _verify(req.password, user.password_hash):
        raise INVALID

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    token = _make_token({
        "sub":       str(user.id),
        "email":     user.email,
        "full_name": user.full_name,
        "role":      user.role,
    })
    return TokenResponse(
        access_token = token,
        user = {
            "id":          user.id,
            "full_name":   user.full_name,
            "email":       user.email,
            "designation": user.designation,
            "role":        user.role,
        }
    )


@router.post("/forgot-password")
def forgot_password(
    req: ForgotPasswordRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    Sends a password reset email via SMTP (Brevo/Gmail).
    Always returns success to prevent user enumeration.
    """
    # Always return success — never reveal if email exists
    SUCCESS = {"success": True, "message": "If this email exists, a reset link has been sent"}

    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        return SUCCESS

   # Delete any existing unused tokens for this user
    db.query(PasswordResetToken).filter(
        PasswordResetToken.user_id == user.id,
        PasswordResetToken.used    == False,
    ).delete()
    db.commit()

    # Create new token valid for 30 minutes
    raw_token = secrets.token_urlsafe(32)
    reset_record = PasswordResetToken(
        user_id    = user.id,
        token      = raw_token,
        expires_at = datetime.utcnow() + timedelta(minutes=30),
        used       = False,
    )
    db.add(reset_record)
    db.commit()

    # Clickable link — Flutter handles /#/reset-password?token=...
    reset_link = f"{APP_BASE_URL}/#/reset-password?token={raw_token}"

    email_body = f"""Dear {user.full_name},

You requested a password reset for your BDOMate.AI account.

Click the link below to reset your password:

{reset_link}

This link expires in 30 minutes.

If you did not request this reset, please ignore this email.

Best regards,
BDOMate.AI
University of South Asia — Business Development Office"""

    try:
        from services.email_sender import send_email_background
        background_tasks.add_task(
            send_email_background,
            to_email = req.email,
            to_name  = user.full_name,
            subject  = "BDOMate.AI — Reset Your Password",
            body     = email_body,
        )
    except ImportError:
        print("[Auth] WARNING: services/email_sender.py not found.")

    return SUCCESS

@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    record = db.query(PasswordResetToken).filter(
        PasswordResetToken.token == req.token,
        PasswordResetToken.used  == False,
    ).first()

    if not record:
        raise HTTPException(
            status_code = 400,
            detail      = "Invalid or expired reset link. Please request a new one."
        )

    if datetime.utcnow() > record.expires_at:
        db.delete(record)
        db.commit()
        raise HTTPException(
            status_code = 400,
            detail      = "This reset link has expired. Please request a new one."
        )

    user = db.query(User).filter(User.id == record.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password_hash = _hash(req.new_password)
    record.used        = True
    db.commit()

    return {
        "success": True,
        "message": "Password updated successfully. You can now log in."
    }

    # Import here to avoid circular import issues at module load time
    try:
        from services.email_sender import send_email_background
        background_tasks.add_task(
            send_email_background,
            to_email = req.email,
            to_name  = user.full_name,
            subject  = "BDOMate.AI — Password Reset Request",
            body     = email_body,
        )
    except ImportError:
        # email_sender.py not installed yet — log and continue
        print("[Auth] WARNING: services/email_sender.py not found. Install aiosmtplib and add the file.")

    return SUCCESS