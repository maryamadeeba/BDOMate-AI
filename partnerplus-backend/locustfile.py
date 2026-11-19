from locust import HttpUser, task, between

class PartnerPlusLoadTest(HttpUser):
    # Simulates a user waiting between 1 and 2 seconds between clicks
    wait_time = between(1, 2)

    @task(1)
    def test_root_endpoint(self):
        """Tests the main landing api endpoint"""
        self.client.get("/")

    @task(2)
    def test_health_check(self):
        """Tests your backend API documentation/status endpoint"""
        self.client.get("/docs")