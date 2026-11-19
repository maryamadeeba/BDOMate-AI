def get_mou_template(mou_type: str) -> str:
    tech = """
    Party No.1: The University of South Asia (USA), 47-Tufail Road, Lahore Cantt.
    Party No.2: [Company Name]
    PURPOSE: Collaboration for joint seminars, panel discussions, workshops,
    promoting education, technology, and business practices.
    RESPONSIBILITIES OF UNIVERSITY: Provide venues, labs, AV equipment, logistical support.
    RESPONSIBILITIES OF COMPANY: Provide expert speakers, C-level executives, explore further collaborations.
    CONFIDENTIALITY: Both parties protect confidential information; no third-party disclosure.
    DURATION: Two academic years. Termination: 30 days written notice.
    """
    ngo = """
    Party No.1: The University of South Asia (USA), 47-Tufail Road, Lahore Cantt.
    Party No.2: [NGO Name]
    PURPOSE: Community upliftment, youth engagement, education enhancement, social development.
    RESPONSIBILITIES OF UNIVERSITY: Provide venues, encourage student volunteering, nominate faculty for campaigns.
    RESPONSIBILITIES OF NGO: Provide trainers, engage community leaders, offer capacity building programs.
    INTERNSHIP TERMS: Undergrad: 2-3 months voluntary. Grad: 15 days-1 month voluntary. Joint certificate issued.
    DURATION: Two years. Termination: 30 days written notice.
    """
    arch = """
    Party No.1: The University of South Asia (USA), Dept of Architecture & Planning.
    Party No.2: [Architecture Firm]
    INTERNSHIP: 12-24 weeks in Architectural Design, MEP Design, BIM Modeling, Project Management.
    RECRUITMENT: Company participates in on-campus drives, presentations, resume reviews, interviews.
    STUDENT DEVELOPMENT: Guest lectures, workshops, career fairs.
    COMPENSATION: Paid internships at company discretion. Company not responsible for student expenses.
    DURATION: Two years. Termination: 30 days. Governed by laws of Pakistan.
    """
    return {"tech_company": tech, "ngo": ngo, "architecture": arch}.get(mou_type, tech)
