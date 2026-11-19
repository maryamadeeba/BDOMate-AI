from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from database.db import get_db
from database.models import Partner, MOURequest, GeneratedMOU
from services.ai_service import generate_mou

router = APIRouter()

class MOUGenerateRequest(BaseModel):
    partner_name:        str
    partner_type:        str
    partner_email:       Optional[str] = ""
    contact_person:      Optional[str] = ""
    partner_phone:       Optional[str] = ""
    partner_address:     Optional[str] = ""
    collaboration_focus: str
    duration_years:      Optional[int] = 2
    special_notes:       Optional[str] = ""

class MOUStatusUpdate(BaseModel):
    status: str

@router.post("/generate")
def generate_new_mou(req: MOUGenerateRequest, db: Session = Depends(get_db)):
    partner = db.query(Partner).filter(Partner.name == req.partner_name).first()
    if not partner:
        partner = Partner(name=req.partner_name, type=req.partner_type,
                         email=req.partner_email, contact_person=req.contact_person,
                         phone=req.partner_phone, address=req.partner_address)
        db.add(partner); db.commit(); db.refresh(partner)
    mou_request = MOURequest(partner_id=partner.id, mou_type=req.partner_type,
                             collaboration_focus=req.collaboration_focus,
                             duration_years=req.duration_years,
                             special_notes=req.special_notes, status="draft")
    db.add(mou_request); db.commit(); db.refresh(mou_request)
    try:
        mou_text = generate_mou(req.partner_name, req.partner_type,
                                req.duration_years, req.collaboration_focus, req.special_notes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI generation failed: {str(e)}")
    generated = GeneratedMOU(request_id=mou_request.id, mou_text=mou_text, version=1)
    db.add(generated); db.commit(); db.refresh(generated)
    return {"success": True, "mou_id": generated.id, "partner": req.partner_name, "mou_text": mou_text}

@router.get("/all")
def get_all_mous(db: Session = Depends(get_db)):
    mous = db.query(GeneratedMOU).order_by(GeneratedMOU.created_at.desc()).all()
    return {"total": len(mous), "mous": [{"id": m.id, "request_id": m.request_id, "version": m.version, "created_at": str(m.created_at)} for m in mous]}

# Add the extra route mapping right here:
@router.get("/list")
@router.get("/all")
def get_all_mous(db: Session = Depends(get_db)):
    mous = db.query(GeneratedMOU).order_by(GeneratedMOU.created_at.desc()).all()
    return {"total": len(mous), "mous": [{"id": m.id, "request_id": m.request_id, "version": m.version, "created_at": str(m.created_at)} for m in mous]}

@router.put("/{mou_id}/status")
def update_status(mou_id: int, body: MOUStatusUpdate, db: Session = Depends(get_db)):
    req = db.query(MOURequest).filter(MOURequest.id == mou_id).first()
    if not req: raise HTTPException(status_code=404, detail="Not found")
    req.status = body.status; db.commit()
    return {"success": True, "new_status": body.status}

@router.delete("/{mou_id}")
def delete_mou(mou_id: int, db: Session = Depends(get_db)):
    mou = db.query(GeneratedMOU).filter(GeneratedMOU.id == mou_id).first()
    if not mou: raise HTTPException(status_code=404, detail="Not found")
    db.delete(mou); db.commit()
    return {"success": True}
