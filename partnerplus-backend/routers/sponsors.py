from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from services.sponsor_service import segment_sponsor

router = APIRouter()


class SponsorRequest(BaseModel):
    sponsor_name:             str
    sponsor_budget:           float
    engagement_score:         float   # 0-100: how active they are
    partnership_years:        float
    interaction_frequency:    float   # number of contacts per year
    last_contribution_amount: float
    org_size_score:           float   # 1-100: size of organization
    industry_sector:          Optional[str] = 'Technology'


@router.post("/segment")
def classify_sponsor(req: SponsorRequest):
    """
    Classifies a sponsor into Bronze / Silver / Gold / Platinum / Diamond
    using the K-Means model trained on 1,000 real sponsor records.
    Also returns recommended BDO actions for this sponsor tier.
    """
    try:
        result = segment_sponsor(
            sponsor_budget           = req.sponsor_budget,
            engagement_score         = req.engagement_score,
            partnership_years        = req.partnership_years,
            interaction_frequency    = req.interaction_frequency,
            last_contribution_amount = req.last_contribution_amount,
            org_size_score           = req.org_size_score,
            industry_sector          = req.industry_sector,
        )
        return {
            "success":      True,
            "sponsor_name": req.sponsor_name,
            **result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
