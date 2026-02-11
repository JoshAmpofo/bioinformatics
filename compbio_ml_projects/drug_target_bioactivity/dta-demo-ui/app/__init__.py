#!/usr/bin/env python3


from flask import Flask


def create_app():
    app = Flask(__name__)
    # import blueprint after app is created
    from .routes import main
    app.register_blueprint(main)
    
    return app

